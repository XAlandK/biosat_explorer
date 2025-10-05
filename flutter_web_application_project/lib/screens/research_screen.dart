import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:biosat_explorer/screens/kg_screen.dart';
import 'package:url_launcher/url_launcher.dart';

final supabase = Supabase.instance.client;

enum ContentView { original, summarized, knowledgeGraph }

class ResearchScreen extends StatefulWidget {
  final int research_id;

  const ResearchScreen({
    super.key,
    required this.research_id,
  });

  @override
  State<ResearchScreen> createState() => _ResearchScreenState();
}

class _ResearchScreenState extends State<ResearchScreen> {
  String? wholeContent;
  Map<String, dynamic>? summaryData;
  bool isLoading = true;
  bool isSummarizing = false;
  String? errorMessage;
  ContentView selectedView = ContentView.original;
  bool hasAttemptedSummary = false;
  String? sourceURL;
  String? researchTitle;
  double fontSize = 16.0; // Default font size

  @override
  void initState() {
    super.initState();
    fetchWholeContent();
    fetchURLOfResearch();
    fetchTitleOfResearch();
  }

  Future<void> fetchWholeContent() async {
    try {
      final response = await supabase
          .from('whole_body_of_each_article')
          .select('whole_content')
          .eq('article_id', widget.research_id)
          .maybeSingle();

      final content = response?['whole_content'] as String?;

      setState(() {
        wholeContent = content;
        isLoading = false;
      });
    } catch (error) {
      print('Error fetching content: $error');
      setState(() {
        errorMessage = "Error loading content.";
        isLoading = false;
      });
    }
  }

  Future<void> fetchURLOfResearch() async {
  try {
    final response = await supabase
        .from('whole_body_of_each_article')
        .select('source_url')  // ✅ Select the correct field
        .eq('article_id', widget.research_id)
        .maybeSingle();

    final url = response?['source_url'] as String?;

    setState(() {
      sourceURL = url;
    });
  } catch (error) {
    print('Error fetching URL: $error');
    setState(() {
      errorMessage = "Error loading URL.";
    });
  }
}

Future<void> fetchTitleOfResearch() async {
  try {
    final response = await supabase
        .from('research_article')
        .select('title')  // ✅ Select the correct field
        .eq('id', widget.research_id)
        .maybeSingle();

    final title = response?['title'] as String?;

    setState(() {
      researchTitle = title;
    });
  } catch (error) {
    print('Error fetching URL: $error');
    setState(() {
      errorMessage = "Error loading URL.";
    });
  }
}

  Future<void> generateSummary(String content) async {
    setState(() {
      isSummarizing = true;
      errorMessage = null;
      hasAttemptedSummary = true;
    });

    try {
      const apiKey = "AIzaSyCJFPc_QWr4FjwzUTzlagh_GRJnfgtx02c";
      const userFocus = "Generate comprehensive summary with knowledge graph";

      final result = await summarizeResearchAndGetKnowledgeGraph(
        content,
        userFocus,
        apiKey,
      );

      setState(() {
        summaryData = result;
        isSummarizing = false;
        if (result == null) {
          errorMessage = "Failed to generate summary. Please try again.";
        }
      });
    } catch (error) {
      print('Error generating summary: $error');
      setState(() {
        errorMessage = "Error generating summary: $error";
        isSummarizing = false;
      });
    }
  }

  Future<Map<String, dynamic>?> summarizeResearchAndGetKnowledgeGraph(
    String researchWebPageDatas,
    String userFocus,
    String apiKey,
  ) async {
    final url =
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey";

    final prompt = """
You are a research summarization assistant.  
Your task is to **generate an intensive, in-depth academic summary** of scientific or research content – written clearly, concisely, and in professional Markdown format – and then produce a structured JSON output that includes a detailed **knowledge graph** of the research concepts.

Primary Input: A block of research web page.  
Secondary Input (User Focus): A short user prompt indicating what to emphasize (e.g., "focus on methodology", "highlight limitations", "generate ratio and knowledge graph").

---

### OUTPUT FORMAT
Return the result **strictly as a JSON object** with the following structure:

{
  "data_retrieval_id": "<unique-uuid-or-hash>",
  "summary_markdown": "<Intensive, well-structured Markdown research summary under 500 words>",
  "knowledge-graph-json-data": {
      "nodes": [
          {"id": "1", "label": "Entity or Concept Name", "type": "Category (e.g., Process, Variable, Organism, etc.)"},
          {"id": "2", "label": "Another Entity", "type": "Category"}
      ],
      "relations": [
          {"source": "1", "target": "2", "relation": "influences / part of / causes / depends on / measures / etc."}
      ]
  }
}

---

### INSTRUCTIONS

#### 1. **data_retrieval_id**
- Generate a unique alphanumeric string or UUID to identify this dataset (e.g., `"bionm1_kg_2025a"` or `"uuid-xxxxxx"`).  
- This will serve as a unique data retrieval reference.

#### 2. **summary_markdown**
- Write an **intensive, information-rich summary** – not just descriptive but **analytically structured**.  
- Use professional **Markdown formatting**, including:
  - Numbered sections and sub-sections (`##`, `###`, `####`)
  - Ordered and unordered lists for clarity
  - **Bold** and *italic* emphasis where relevant
  - Tables or inline charts (text-based) for ratios or comparisons  
- Focus on **depth and organization**:
  - Present multiple **topics and subtopics**
  - Highlight **objectives**, **methods**, **results**, **implications**, and **limitations** where applicable
  - Integrate **ratios**, **metrics**, or **comparative data** (e.g., "X/Y ratio = 1.5") in textual form
  - Maintain **academic tone and logical coherence**
- Must remain under 500 words.  
- Do **not** include citations, extraneous commentary, or prefixes like "Here's the summary".

#### 3. **knowledge-graph-json-data**
- Extract and represent the **key entities, processes, variables, and their relationships** from the research.  
- Each entity or concept must be a node with attributes:
  - `"id"` (unique identifier)
  - `"label"` (entity or concept name)
  - `"type"` (e.g., Organism, Process, Parameter, Result, etc.)
- Each relationship is a directed link with attributes:
  - `"source"` (originating node ID)
  - `"target"` (connected node ID)
  - `"relation"` (type of connection, such as "affects", "depends on", "influences", "causes", "part of", "measured by")  
- Keep text **plain (no Markdown)** inside JSON.  
- Ensure the graph is **machine-readable**, logically consistent, and aligned with the summary's conceptual structure.

---

Now, summarize the following research based on the user's focus.

Research web pages datas:  
\"\"\"$researchWebPageDatas\"\"\"

User Focus:  
\"\"\"$userFocus\"\"\"


Also, in the summarization process, try to:
1.  Identify areas of scientific progress.
2.  identify knowledge gaps (identify gaps where additional research is needed).
3.  Identify areas of consensus or disagreement.
4.  Provide actionable insights to mission planners (provide actionable information).
5.  Describe research progress.
""";

    final body = {
      "contents": [
        {
          "role": "user",
          "parts": [
            {"text": prompt},
          ],
        },
      ],
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (response.statusCode != 200) {
        return null;
      }

      final data = jsonDecode(response.body);
      var text =
          data["candidates"]?[0]?["content"]?["parts"]?[0]?["text"] ?? "";

      text = text
          .replaceAll(RegExp(r'```json'), '')
          .replaceAll(RegExp(r'```'), '')
          .trim();

      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(text);
      final cleaned = jsonMatch?.group(0);

      if (cleaned == null || cleaned.isEmpty) {
        return null;
      }

      final parsedJson = json.decode(cleaned) as Map<String, dynamic>;

      return parsedJson;
    } catch (e) {
      return null;
    }
  }

  String getHtmlContent() {
    final knowledgeGraphData = summaryData?['knowledge-graph-json-data'];
    final jsonString = jsonEncode(knowledgeGraphData ?? {});

    print(jsonString);

    return """
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Knowledge Graph – Bion-M 1</title>
  <link rel="stylesheet" href="https://unpkg.com/vis-network/styles/vis-network.min.css" />
  <style>
    body { font-family: Inter, system-ui, -apple-system, "Segoe UI", Roboto, "Helvetica Neue", Arial; margin: 0; height: 100vh; }
    #network { width: 100%; height: 100vh; background: #fafafa; }
  </style>
</head>
<body>
  <div id="network"></div>

  <script src="https://unpkg.com/vis-network/standalone/umd/vis-network.min.js"></script>
  <script>
    const dataJson = $jsonString;

    const typeColor = {
      'Experiment': '#2b8cff',
      'Organism': '#ff7f50',
      'Process': '#7bd389',
      'Cell Type': '#a980ff',
      'Tool/Method': '#ffa94d',
      'Parameter': '#b0b0b0'
    };

    const nodes = dataJson.nodes.map(n => ({
      id: n.id,
      label: n.label,
      title: `\${n.label} (\${n.type})`,
      group: n.type,
      color: { background: typeColor[n.type] || '#cccccc', border: '#666' },
      shape: 'ellipse',
      font: { multi: 'html' }
    }));

    const edges = dataJson.relations.map(r => ({
      from: r.source,
      to: r.target,
      label: r.relation,
      arrows: 'to',
      font: { align: 'middle' },
      smooth: { type: 'cubicBezier' }
    }));

    const container = document.getElementById('network');
    const data = { nodes: new vis.DataSet(nodes), edges: new vis.DataSet(edges) };
    const options = {
      groups: {},
      interaction: { hover: true, multiselect: false },
      physics: { stabilization: true, barnesHut: { gravitationalConstant: -3000, springLength: 150 } },
      edges: { color: { color: '#666' }, font: { size: 12 } },
      nodes: { borderWidth: 2, chosen: { node: function(values, id, selected, hovering) { values.borderWidth = 4 } } }
    };

    const network = new vis.Network(container, data, options);

    network.on('click', function(params) {
      if (params.nodes.length) {
        const nodeId = params.nodes[0];
        const connected = network.getConnectedNodes(nodeId);
        data.nodes.forEach(n => data.nodes.update({ id: n.id, color: { background: '#eee', border: '#ddd' } }));
        data.nodes.update({ id: nodeId, color: { background: '#fff200', border: '#ff7700' } });
        connected.forEach(id => {
          const node = data.nodes.get(id);
          data.nodes.update({ id: id, color: { background: typeColor[node.group] || '#ddd', border: '#666' } });
        });
      } else {
        data.nodes.forEach(n => data.nodes.update({ id: n.id, color: { background: typeColor[n.group] || '#ddd', border: '#666' } }));
      }
    });

    network.once('afterDrawing', () => network.fit({ animation: true }));
  </script>
</body>
</html>
""";
  }

  Widget _buildOriginalContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Text(
            wholeContent ?? "No content found.",
            textAlign: TextAlign.justify,
            style: TextStyle(
              inherit: false,
              fontSize: fontSize,
              height: 1.5),
          ),
    );
  }

  Widget _buildSummarizedContent() {
  if (!hasAttemptedSummary && wholeContent != null && wholeContent!.isNotEmpty) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blueAccent.shade100.withOpacity(0.3),
                    Colors.blueAccent.shade200.withOpacity(0.2),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.blueAccent.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.auto_awesome,
                size: 64,
                color: Colors.blueAccent.shade700,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Generate AI Summary",
              style: TextStyle(
                inherit: false,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Click the button below to generate an AI-powered summary and knowledge graph of this research content.",
              textAlign: TextAlign.center,
              style: TextStyle(
                inherit: false,
                fontSize: 16,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => generateSummary(wholeContent!),
              icon: const Icon(Icons.psychology, color: Colors.white),
              label: const Text(
                "Generate Summary",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                elevation: 3,
                shadowColor: Colors.blueAccent.withOpacity(0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  if (isSummarizing) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            "Generating AI summary...",
            style: TextStyle(
              inherit: false,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "This may take a moment",
            style: TextStyle(
              inherit: false,
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  if (errorMessage != null) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.red.shade50,
                    Colors.red.shade100.withOpacity(0.5),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.shade300, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.error_outline,
                      color: Colors.red.shade700,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      inherit: false,
                      color: Colors.red.shade700,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => generateSummary(wholeContent!),
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text(
                "Try Again",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade400,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  if (summaryData != null) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              // gradient: LinearGradient(
              //   colors: [
              //     Colors.blueAccent,
              //     Colors.white,
              //   ],
              //   begin: Alignment.topLeft,
              //   end: Alignment.bottomRight,
              // ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.blueAccent.shade200,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.blueAccent.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.auto_awesome,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "AI-Generated Summary",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                MarkdownBody(
                  data: summaryData!['summary_markdown'] ?? "No summary available",
                  styleSheet: MarkdownStyleSheet(
                    p: TextStyle(
                      inherit: false,
                      fontSize: fontSize,
                      height: 1.6,
                      color: Colors.black87,
                    ),
                    h1: TextStyle(
                      inherit: false,
                      fontSize: fontSize + 8,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent.shade700,
                    ),
                    h2: TextStyle(
                      inherit: false,
                      fontSize: fontSize + 6,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                    h3: TextStyle(
                      inherit: false,
                      fontSize: fontSize + 4,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                    h4: TextStyle(
                      inherit: false,
                      fontSize: fontSize + 2,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                    listBullet: TextStyle(
                      inherit: false,
                      fontSize: fontSize,
                      color: Colors.blueAccent.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (summaryData!['knowledge-graph-json-data'] != null) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.green.shade50,
                    Colors.green.shade100.withOpacity(0.3),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.green.shade300,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green.shade200,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.hub,
                                color: Colors.green.shade800,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              "Knowledge Graph Available",
                              style: TextStyle(
                                inherit: false,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "Nodes: ${((summaryData!['knowledge-graph-json-data'] as Map?)?['nodes'] as List?)?.length ?? 0} • Relations: ${((summaryData!['knowledge-graph-json-data'] as Map?)?['relations'] as List?)?.length ?? 0}",
                            style: TextStyle(
                              inherit: false,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.green.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        selectedView = ContentView.knowledgeGraph;
                      });
                    },
                    icon: const Icon(Icons.hub, color: Colors.white),
                    label: const Text(
                      'View Graph',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  return Center(
    child: Text(
      "No summary available",
      style: TextStyle(
        color: Colors.grey.shade600,
        fontSize: 16,
      ),
    ),
  );
}

Widget _buildKnowledgeGraphContent() {
  if (summaryData == null || summaryData!['knowledge-graph-json-data'] == null) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 3,
                ),
              ),
              child: Icon(
                Icons.hub_outlined,
                size: 64,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "No Knowledge Graph Available",
              style: TextStyle(
                inherit: false,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Generate an AI summary first to create a knowledge graph.",
              textAlign: TextAlign.center,
              style: TextStyle(
                inherit: false,
                fontSize: 16,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  selectedView = ContentView.summarized;
                });
              },
              icon: const Icon(Icons.auto_awesome, color: Colors.white),
              label: const Text(
                "Go to AI Summary",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  return Column(
    children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.green.shade100,
              Colors.green.shade50,
            ],
          ),
          border: Border(
            bottom: BorderSide(
              color: Colors.green.shade300,
              width: 2,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.info_outline,
                color: Colors.green.shade800,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Click nodes to highlight connections • Drag to explore • ${((summaryData!['knowledge-graph-json-data'] as Map?)?['nodes'] as List?)?.length ?? 0} nodes, ${((summaryData!['knowledge-graph-json-data'] as Map?)?['relations'] as List?)?.length ?? 0} relations",
                style: TextStyle(
                  inherit: false,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade800,
                ),
              ),
            ),
          ],
        ),
      ),
      Expanded(
        child: KnowledgeGraphWidget(
          htmlContent: getHtmlContent(),
        ),
      ),
    ],
  );
}

  void _showFontSizeControl(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Adjust Font Size'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Preview Text',
                    style: TextStyle(fontSize: fontSize),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        iconSize: 32,
                        onPressed: fontSize > 10
                            ? () {
                                setDialogState(() {
                                  setState(() {
                                    fontSize -= 2;
                                  });
                                });
                              }
                            : null,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${fontSize.toInt()}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        iconSize: 32,
                        onPressed: fontSize < 32
                            ? () {
                                setDialogState(() {
                                  setState(() {
                                    fontSize += 2;
                                  });
                                });
                              }
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Range: 10 - 32',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      fontSize = 16.0; // Reset to default
                    });
                    Navigator.of(context).pop();
                  },
                  child: const Text('Reset'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Done'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.grey.shade50,
    appBar: AppBar(
      title: Text(
        "Research Content",
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      elevation: 0,
      backgroundColor: Colors.blueAccent,
      foregroundColor: Colors.white,
      actions: [
        if (selectedView == ContentView.original || 
            selectedView == ContentView.summarized)
          IconButton(
            icon: const Icon(Icons.text_fields),
            tooltip: 'Adjust Font Size',
            onPressed: () => _showFontSizeControl(context),
          ),
        IconButton(
          icon: const Icon(Icons.open_in_new),
          tooltip: 'Open URL',
          onPressed: () async {
            final Uri url = Uri.parse(sourceURL!);
            if (await canLaunchUrl(url)) {
              await launchUrl(url, mode: LaunchMode.externalApplication);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Could not open the URL'),
                  backgroundColor: Colors.red.shade400,
                ),
              );
            }
          },
        ),
      ],
    ),
    body: isLoading
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: Colors.blueAccent,
                  strokeWidth: 3,
                ),
                const SizedBox(height: 16),
                Text(
                  'Loading research content...',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          )
        : Column(
            children: [
              // Research Info Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.blueAccent.shade100.withOpacity(0.3),
                      Colors.blueAccent.shade100.withOpacity(0.2),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.blueAccent.shade100,
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.shade100.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.blueAccent.shade200,
                        ),
                      ),
                      child: Text(
                        "Research ID: ${widget.research_id}",
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.blueAccent.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (researchTitle != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        researchTitle!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade800,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              
              // Segmented Button
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blueAccent.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: SegmentedButton<ContentView>(
                  segments: [
                    ButtonSegment<ContentView>(
                      value: ContentView.original,
                      label: const Text('Original Content'),
                      icon: Icon(
                        Icons.article,
                        color: selectedView == ContentView.original
                            ? Colors.white
                            : Colors.blueAccent,
                      ),
                    ),
                    ButtonSegment<ContentView>(
                      value: ContentView.summarized,
                      label: const Text('AI Summary'),
                      icon: Icon(
                        Icons.auto_awesome,
                        color: selectedView == ContentView.summarized
                            ? Colors.white
                            : Colors.blueAccent,
                      ),
                    ),
                    ButtonSegment<ContentView>(
                      value: ContentView.knowledgeGraph,
                      label: const Text('Knowledge Graph'),
                      icon: Icon(
                        Icons.hub,
                        color: selectedView == ContentView.knowledgeGraph
                            ? Colors.white
                            : Colors.blueAccent,
                      ),
                    ),
                  ],
                  selected: {selectedView},
                  onSelectionChanged: (Set<ContentView> newSelection) {
                    setState(() {
                      selectedView = newSelection.first;
                    });
                  },
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return Colors.blueAccent;
                      }
                      return Colors.white;
                    }),
                    foregroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return Colors.white;
                      }
                      return Colors.blueAccent;
                    }),
                    side: WidgetStateProperty.all(
                      BorderSide(color: Colors.blueAccent.shade200),
                    ),
                  ),
                ),
              ),
              
              Divider(height: 1, color: Colors.blueAccent.shade100),
              
              // Content Area
              Expanded(
                child: selectedView == ContentView.original
                    ? _buildOriginalContent()
                    : selectedView == ContentView.summarized
                        ? _buildSummarizedContent()
                        : _buildKnowledgeGraphContent(),
              ),
            ],
          ),
  );
}
}