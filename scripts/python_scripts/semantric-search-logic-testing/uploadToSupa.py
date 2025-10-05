import json
from supabase import create_client, Client

# --- CONFIG ---
SUPABASE_URL = "https://rvxkdsrryfpkvdzzkmnm.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ2eGtkc3JyeWZwa3ZkenprbW5tIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkxODE5OTUsImV4cCI6MjA3NDc1Nzk5NX0._ylejG3TbqCbjRvZcgimG-TD8yiE-gkHR_3cpnfvJrY"
TABLE_NAME = "nyan"
JSON_FILE = "title_vectors.json"

# --- INIT SUPABASE CLIENT ---
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

# --- LOAD JSON DATA ---
with open(JSON_FILE, "r", encoding="utf-8") as f:
    data = json.load(f)

# --- FORMAT DATA ---
rows_to_insert = [
    {"research_paper_id": item["id"], "embedding": item["vector"]}
    for item in data
]

# --- BATCH UPLOAD ---
BATCH_SIZE = 100

for i in range(0, len(rows_to_insert), BATCH_SIZE):
    batch = rows_to_insert[i:i + BATCH_SIZE]
    response = supabase.table(TABLE_NAME).insert(batch).execute()
    if hasattr(response, "error") and response.error is not None:
        print(f"❌ Error uploading batch {i // BATCH_SIZE + 1}: {response.error}")
    else:
        print(f"✅ Batch {i // BATCH_SIZE + 1} uploaded successfully!")

print("🎉 All batches processed.")
