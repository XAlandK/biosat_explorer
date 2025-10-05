// Node.js version - updated with fixes
const axios = require("axios");
const { JSDOM } = require("jsdom");
const fs = require("fs");
const urls = require("./urls");
const path = require("path");

// Main function to extract data from a PMC URL
async function extractArticleDataFromURL(url) {
  try {
    // Fetch HTML content from the URL
    const htmlContent = await fetchHTMLContent(url);

    // Extract data from the HTML content
    const articleData = extractArticleData(htmlContent, url);
    articleData.sourceURL = url;

    // Fetch similar articles and cited by articles
    const resourcesData = await fetchAdditionalResources(htmlContent, url);
    articleData.similarArticles = resourcesData.similarArticles;
    articleData.citedByArticles = resourcesData.citedByArticles;

    return articleData;
  } catch (error) {
    console.error(`Error processing URL ${url}:`, error.message);
    return { error: error.message, sourceURL: url };
  }
}

// Function to fetch HTML content from a URL (Node.js version)
async function fetchHTMLContent(url) {
  try {
    const response = await axios.get(url, {
      headers: {
        "User-Agent":
          "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
      },
    });

    return response.data;
  } catch (error) {
    throw new Error(`Failed to fetch HTML from ${url}: ${error.message}`);
  }
}

// Function to fetch similar articles and cited by articles
async function fetchAdditionalResources(htmlContent, url) {
  const dom = new JSDOM(htmlContent);
  const doc = dom.window.document;

  const resources = {
    similarArticles: [],
    citedByArticles: [],
  };

  try {
    // Extract PMID from meta tag
    const pmidMeta = doc.querySelector('meta[name="citation_pmid"]');
    const pmid = pmidMeta ? pmidMeta.getAttribute("content") : "";

    if (pmid) {
      // Fetch similar articles
      const similarArticlesURL = `https://pmc.ncbi.nlm.nih.gov/resources/similar-article-links/${pmid}/`;
      try {
        const similarArticlesHTML = await fetchHTMLContent(similarArticlesURL);
        resources.similarArticles = extractArticleList(
          similarArticlesHTML,
          "similar_articles"
        );
      } catch (error) {
        console.error(
          `Error fetching similar articles for PMID ${pmid}:`,
          error.message
        );
      }

      // Fetch cited by articles
      const citedByURL = `https://pmc.ncbi.nlm.nih.gov/resources/cited-by-links/${pmid}/`;
      try {
        const citedByHTML = await fetchHTMLContent(citedByURL);
        resources.citedByArticles = extractArticleList(citedByHTML, "cited_by");
      } catch (error) {
        console.error(
          `Error fetching cited by articles for PMID ${pmid}:`,
          error.message
        );
      }
    }
  } catch (error) {
    console.error("Error fetching additional resources:", error.message);
  }

  return resources;
}

// Function to extract article list from HTML
function extractArticleList(htmlContent, type) {
  const dom = new JSDOM(htmlContent);
  const doc = dom.window.document;

  const articles = [];

  const listItems = doc.querySelectorAll("li");
  listItems.forEach((item) => {
    const link = item.querySelector("a");
    const journalInfo = item.querySelector(".font-body-2xs");

    if (link) {
      const article = {
        title: link.textContent.trim(),
        url: link.getAttribute("href") || "",
        journal: journalInfo ? journalInfo.textContent.trim() : "",
      };

      articles.push(article);
    }
  });

  return articles;
}

// Function to extract data from HTML content (UPDATED)
function extractArticleData(htmlContent, url) {
  const dom = new JSDOM(htmlContent);
  const doc = dom.window.document;

  const result = {
    title: "",
    authors: "",
    publishedAt: "",
    doi: "",
    bodyContent: [],
    references: [],
    pmid: "",
    pmcId: "",
    tables: [],
  };

  try {
    // 1. Extract title value
    const titleElement = doc.querySelector("title");
    if (titleElement) {
      result.title = titleElement.textContent.trim().replace(" - PMC", "");
    }

    // 2. Extract authors
    const authorElements = doc.querySelectorAll(".cg.p a[aria-describedby]");
    const authors = [];
    authorElements.forEach((author) => {
      const nameElement = author.querySelector(".name.western");
      if (nameElement) {
        authors.push(nameElement.textContent.trim());
      }
    });
    result.authors = authors.join(", ");

    // 3. Extract published at information
    const citationElement = doc.querySelector(".pmc-layout__citation");
    if (citationElement) {
      const citationText = citationElement.textContent;
      const publishedMatch = citationText.match(
        /\d{4}\s+[A-Za-z]+\s+\d+;\d+\(\d+\):[^ ]+/
      );
      if (publishedMatch) {
        result.publishedAt = publishedMatch[0];
      }
    }

    // 4. Extract DOI
    const doiMeta = doc.querySelector('meta[name="citation_doi"]');
    if (doiMeta) {
      result.doi = doiMeta.getAttribute("content") || "";
    }

    // Fallback: Try to extract from link text
    if (!result.doi) {
      const doiLink = doc.querySelector('a[href*="doi.org"]');
      if (doiLink) {
        const doiText = doiLink.textContent.trim();
        const doiMatch = doiText.match(/(10\.[0-9]+\/[^&\s]+)/);
        if (doiMatch) {
          result.doi = doiMatch[1];
        } else {
          result.doi = doiText;
        }
      }
    }

    // Extract PMC ID from URL
    const pmcIdMatch = url.match(/PMC(\d+)/);
    if (pmcIdMatch) {
      result.pmcId = `PMC${pmcIdMatch[1]}`;
    }

    // Extract PMID
    const pmidMeta = doc.querySelector('meta[name="citation_pmid"]');
    if (pmidMeta) {
      result.pmid = pmidMeta.getAttribute("content") || "";
    }

    // 5. Extract body content - simplified without metadata
    const bodySections = doc.querySelectorAll(
      ".main-article-body > section, .body > section, .main-article-body section"
    );
    bodySections.forEach((section) => {
      const sectionData = {
        heading: "",
        content: "",
        tables: [],
      };

      // Extract heading
      const heading = section.querySelector("h1, h2, h3, h4, h5, h6");
      if (heading) {
        sectionData.heading = heading.textContent
          .trim()
          .replace(/^[\d\.]+\s*/, "");
      }

      // Extract content - simplified without link metadata
      const paragraphs = section.querySelectorAll("p");
      sectionData.content = Array.from(paragraphs)
        .map((p) => {
          // Simply get text content without preserving link structure
          return p.textContent.trim();
        })
        .filter((text) => text.length > 0)
        .join("\n\n");

      // Extract tables - simplified structure
      const tableElements = section.querySelectorAll("table");
      tableElements.forEach((table) => {
        const tableData = extractSimpleTableData(table);
        if (tableData.rows.length > 0) {
          sectionData.tables.push(tableData);
          // Also add to global tables array
          result.tables.push({
            ...tableData,
            section: sectionData.heading || "Unknown",
          });
        }
      });

      if (
        sectionData.heading ||
        sectionData.content ||
        sectionData.tables.length > 0
      ) {
        result.bodyContent.push(sectionData);
      }
    });

    // 6. Extract references - simplified
    const refElements = doc.querySelectorAll(
      ".ref-list li, .ref-list font-sm li"
    );
    refElements.forEach((ref) => {
      const reference = {
        id: ref.getAttribute("id") || "",
        citation: ref.textContent.trim(),
      };

      if (reference.citation) {
        result.references.push(reference);
      }
    });
  } catch (error) {
    console.error("Error extracting data:", error);
    result.error = error.message;
  }

  return result;
}

// Function to extract table data in simple format
function extractSimpleTableData(table) {
  const tableData = {
    caption: "",
    headers: [],
    rows: [],
  };

  // Extract table caption
  const captionElement = table.querySelector("caption");
  if (captionElement) {
    tableData.caption = captionElement.textContent.trim();
  }

  // Extract all rows (including header rows)
  const allRows = table.querySelectorAll("tr");

  allRows.forEach((row) => {
    const cells = Array.from(row.querySelectorAll("th, td")).map((cell) => {
      // Simply get text content without colspan/rowspan metadata
      return cell.textContent.trim();
    });

    if (cells.length > 0) {
      // If this is likely a header row (contains th elements or is in thead)
      if (row.querySelector("th") || row.closest("thead")) {
        tableData.headers.push(cells);
      } else {
        tableData.rows.push(cells);
      }
    }
  });

  return tableData;
}

// Function to process multiple URLs
async function processMultipleURLs(urls) {
  const results = [];

  console.log("--------------------urls============");
  console.log(urls);
  console.log("--------------------urls============");
  for (const url of urls) {
    try {
      console.log(`Processing: ${url}`);
      const articleData = await extractArticleDataFromURL(url);
      results.push(articleData);

      // Add delay to be respectful to the server
      await new Promise((resolve) => setTimeout(resolve, 1000));
    } catch (error) {
      console.error(`Error processing URL ${url}:`, error.message);
      results.push({ error: error.message, sourceURL: url });
    }
  }

  return results;
}

// Function to save results as JSON file
function saveResultsAsJSON(results, filename) {
  fs.writeFileSync(filename, JSON.stringify(results, null, 2));
  console.log(`Results saved to ${filename}`);
}

// Function to generate a detailed report
function generateReport(results) {
  let report = `PMC Article Extraction Report\n`;
  report += `Generated: ${new Date().toISOString()}\n`;
  report += `Total articles processed: ${results.length}\n\n`;

  results.forEach((result, index) => {
    report += `Article ${index + 1}: ${result.title || "No title"}\n`;
    report += `URL: ${result.sourceURL}\n`;
    report += `DOI: ${result.doi || "Not found"}\n`;
    report += `Sections: ${result.bodyContent?.length || 0}\n`;
    report += `Tables: ${result.tables?.length || 0}\n`;
    report += `References: ${result.references?.length || 0}\n`;
    report += `Similar Articles: ${result.similarArticles?.length || 0}\n`;
    report += `Cited By Articles: ${result.citedByArticles?.length || 0}\n`;
    report += `---\n`;
  });

  return report;
}

// Main execution function
async function main() {
  console.log("Starting PMC article extraction...");

  // Ensure output directory exists
  const outputDir = path.join(__dirname, "output-v4••");
  if (!fs.existsSync(outputDir)) {
    fs.mkdirSync(outputDir);
  }

  const batchSize = 5;
  const totalBatches = Math.ceil(urls.length / batchSize);

  for (let batchIndex = 0; batchIndex < totalBatches; batchIndex++) {
    const start = batchIndex * batchSize;
    const end = start + batchSize;
    const batchURLs = urls.slice(start, end);

    console.log(`Processing batch ${batchIndex + 1} of ${totalBatches}`);
    const batchResults = await processMultipleURLs(batchURLs);

    const filePath = path.join(outputDir, `v4-${batchIndex}.json`);
    saveResultsAsJSON(batchResults, filePath);
  }

  console.log("All batches processed and saved in /output directory.");
}

// Run if this file is executed directly
if (require.main === module) {
  main().catch(console.error);
}

module.exports = {
  extractArticleDataFromURL,
  processMultipleURLs,
  saveResultsAsJSON,
  generateReport,
};
