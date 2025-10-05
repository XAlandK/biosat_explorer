import 'dotenv/config';

import { createClient } from '@supabase/supabase-js';
import fs from 'fs';

const supabase = createClient(
  // process.env.SUPABASE_URL,
  // process.env.SUPABASE_SERVICE_ROLE_KEY
  "https://rvxkdsrryfpkvdzzkmnm.supabase.co",
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ2eGtkc3JyeWZwa3ZkenprbW5tIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkxODE5OTUsImV4cCI6MjA3NDc1Nzk5NX0._ylejG3TbqCbjRvZcgimG-TD8yiE-gkHR_3cpnfvJrY"
);

const BATCH_SIZE = 50;   // rows per batch (keep small to avoid payload limits)
const BATCH_DELAY = 500; // ms between batches

// helpers
function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

function chunkArray(arr, size) {
  const chunks = [];
  for (let i = 0; i < arr.length; i += size) {
    chunks.push(arr.slice(i, i + size));
  }
  return chunks;
}

// Insert or get ID (avoids duplicates for authors, keywords, datasets, etc.)
async function insertOrGet(table, uniqueField, value, extra = {}) {
  if (!value) return null;

  const { data, error } = await supabase.from(table).select('id').eq(uniqueField, value).maybeSingle();
  if (error) {
    console.error(`❌ Error selecting from ${table}:`, error.message);
    return null;
  }
  if (data) return data.id;

  const { data: inserted, error: insertError } = await supabase
    .from(table)
    .insert([{ [uniqueField]: value, ...extra }])
    .select('id')
    .single();

  if (insertError) {
    console.error(`❌ Error inserting into ${table}:`, insertError.message);
    return null;
  }
  return inserted.id;
}

// Upload one research article and its relations
async function uploadResearch(article) {
  try {
    // ========== research_article ==========
    const articleRow = {
      title: article.title,
      published_at: article.publishedAt ? article.publishedAt.substring(0, 10) : null,
      doi: article.doi,
      pmid: article.pmid,
      pmc_id: article.pmcId,
      source_url: article.sourceURL,
    };

    const { data: insertedArticle, error: insertArticleError } = await supabase
      .from('research_article')
      .insert([articleRow])
      .select('id')
      .single();

    if (insertArticleError) {
      console.error("❌ Error inserting article:", article.title, insertArticleError.message);
      return;
    }

    const researchArticleId = insertedArticle.id;

    // ========== authors ==========
    if (article.authors) {
      const authors = article.authors.split(',').map(a => a.trim());
      for (const name of authors) {
        const authorId = await insertOrGet('author', 'full_name', name);
        if (authorId) {
          await supabase.from('article_author').insert([{ research_article_id: researchArticleId, author_id: authorId }]);
        }
      }
    }

    // ========== body_content & tables ==========
    if (article.bodyContent) {
      for (const section of article.bodyContent) {
        const { data: body, error: bodyErr } = await supabase
          .from('body_content')
          .insert([{ research_article_id: researchArticleId, heading: section.heading, content: section.content }])
          .select('id')
          .single();

        if (bodyErr) continue;
        const bodyContentId = body.id;

        if (section.tables) {
          for (const tbl of section.tables) {
            const { data: tableRow } = await supabase
              .from('experiment_table')
              .insert([{
                research_article_id: researchArticleId,
                body_content_id: bodyContentId,
                caption: tbl.caption,
                section: tbl.section,
              }])
              .select('id')
              .single();

            const tableId = tableRow.id;
            if (tbl.rows) {
              let idx = 0;
              for (const row of tbl.rows) {
                await supabase.from('experiment_table_row').insert([{
                  experiment_table_id: tableId,
                  row_index: idx++,
                  cells: row
                }]);
              }
            }
          }
        }
      }
    }

    // ========== references ==========
    if (article.references) {
      const rows = article.references.map(ref => ({
        research_article_id: researchArticleId,
        citation_id: ref.id,
        citation_text: ref.citation,
      }));
      if (rows.length) await supabase.from('reference').insert(rows);
    }

    // ========== similar_articles ==========
    if (article.similarArticles) {
      const rows = article.similarArticles.map(sim => ({
        research_article_id: researchArticleId,
        title: sim.title,
        url: sim.url,
        journal: sim.journal,
      }));
      if (rows.length) await supabase.from('similar_article').insert(rows);
    }

    // ========== cited_by_articles ==========
    if (article.citedByArticles) {
      const rows = article.citedByArticles.map(cb => ({
        research_article_id: researchArticleId,
        title: cb.title,
        url: cb.url,
        journal: cb.journal,
      }));
      if (rows.length) await supabase.from('cited_by_article').insert(rows);
    }

    // ========== keywords ==========
    if (article.bodyContent) {
      for (const section of article.bodyContent) {
        if (section.heading && section.heading.toLowerCase() === 'keywords') {
          const keywords = section.content.split(',').map(k => k.trim());
          for (const kw of keywords) {
            const kwId = await insertOrGet('keyword', 'term', kw);
            if (kwId) {
              await supabase.from('article_keyword').insert([{ research_article_id: researchArticleId, keyword_id: kwId }]);
            }
          }
        }
      }
    }

    // ========== datasets (if provided) ==========
    if (article.datasets) {
      for (const ds of article.datasets) {
        const dsId = await insertOrGet('dataset', 'identifier', ds.identifier, { name: ds.name, source: ds.source });
        if (dsId) {
          await supabase.from('article_dataset').insert([{ research_article_id: researchArticleId, dataset_id: dsId }]);
        }
      }
    }

    console.log(`✅ Inserted: ${article.title}`);
  } catch (err) {
    console.error("❌ Unexpected error:", err.message);
  }
}

async function main() {
  const raw = fs.readFileSync('researches.json', 'utf-8');
  const articles = JSON.parse(raw);
  console.log(`Found ${articles.length} research articles`);

  const chunks = chunkArray(articles, BATCH_SIZE);
  for (let i = 0; i < chunks.length; i++) {
    console.log(`📥 Processing batch ${i + 1}/${chunks.length}`);
    for (const article of chunks[i]) {
      await uploadResearch(article);
    }
    await sleep(BATCH_DELAY);
  }

  console.log("🎉 All research articles uploaded successfully!");
}

main();
