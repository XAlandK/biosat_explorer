import os
import json
import numpy as np
import pandas as pd
from google import genai
from google.genai import types

# --- CONFIG ---
# os.environ["GEMINI_API_KEY"] = "AIzaSyCohYqs6O0m_k4uTzgLk9MKVm2L1jKMsWE"
API_KEY = "AIzaSyCohYqs6O0m_k4uTzgLk9MKVm2L1jKMsWE"  
EMBEDDING_MODEL = "gemini-embedding-001"
VECTORS_FILE = "title_vectors.json"
CSV_FILE = "title.csv"

# --- Init client ---
client = genai.Client(api_key=API_KEY)

# --- Load data ---
with open(VECTORS_FILE, "r", encoding="utf-8") as f:
    vectors_data = json.load(f)

import pandas as pd
titles_df = pd.read_csv(CSV_FILE)
titles_map = dict(zip(titles_df["id"], titles_df["title"]))

# --- Cosine similarity ---
def cosine_similarity(a, b):
    a = np.array(a)
    b = np.array(b)
    return np.dot(a, b) / (np.linalg.norm(a) * np.linalg.norm(b))

# --- Function: embed a query ---
def embed_query(query):
    response = client.models.embed_content(
        model=EMBEDDING_MODEL,
        contents=[query],
        config=types.EmbedContentConfig(
            task_type="RETRIEVAL_QUERY"  # correct type for search queries
        ),
    )
    return response.embeddings[0].values


# --- Function: search ---
def search(query, top_k=5):
    print(f"\n🔍 Searching for: {query}\n")
    query_vec = embed_query(query)
    results = []

    for item in vectors_data:
        sim = cosine_similarity(query_vec, item["vector"])
        results.append((item["id"], sim))

    # Sort by similarity (descending)
    results.sort(key=lambda x: x[1], reverse=True)
    top_results = results[:top_k]

    print(f"Top {top_k} matches:\n")
    for id_, score in top_results:
        title = titles_map.get(id_, "Unknown Title")
        print(f"⭐ ID {id_} | Score: {score:.4f} | Title: {title}")

# --- Example ---
if __name__ == "__main__":
    user_query = input("Enter your search query: ")
    search(user_query)
