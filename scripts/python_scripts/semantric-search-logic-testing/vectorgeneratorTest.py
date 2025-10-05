import os
import json
import pandas as pd
from google import genai
from google.genai import types

# --- CONFIG ---
os.environ["GEMINI_API_KEY"] = "AIzaSyCohYqs6O0m_k4uTzgLk9MKVm2L1jKMsWE"
EMBEDDING_MODEL = "gemini-embedding-001"

# --- Initialize client ---
client = genai.Client()

# --- Load CSV ---
csv_path = "title.csv"  # your input file
df = pd.read_csv(csv_path)

# --- Prepare output list ---
results = []

# --- Embed each title ---
for _, row in df.iterrows():
    text = str(row["title"])
    id_ = int(row["id"])

    try:
        response = client.models.embed_content(
            model=EMBEDDING_MODEL,
            contents=[text],  # must be a list
            config=types.EmbedContentConfig(
                task_type="RETRIEVAL_DOCUMENT",
                title="Research Title Embedding"
            ),
        )
        # Access embedding correctly
        vector = response.embeddings[0].values
        results.append({"id": id_, "vector": vector})
        print(f"✅ Embedded ID {id_}: {len(vector)} dimensions {vector}")

    except Exception as e:
        print(f"❌ Error embedding ID {id_}: {e}")

# --- Save to JSON ---
with open("title_vectors.json", "w", encoding="utf-8") as f:
    json.dump(results, f, indent=2)

print("\n🎉 Done! Saved embeddings to 'title_vectors.json'")
