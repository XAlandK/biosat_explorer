import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:biosat_explorer/models/research_model.dart';
import 'package:biosat_explorer/providers/supabase_single_research_provider.dart';
import 'package:biosat_explorer/screens/research_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class SemanticSearchScreen extends StatefulWidget {
  const SemanticSearchScreen({super.key});

  @override
  _SemanticSearchScreenState createState() => _SemanticSearchScreenState();
}

class _SemanticSearchScreenState extends State<SemanticSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  List<ResearchModel> results = [];
  bool isLoading = false;
  bool hasSearched = false; // Track if user has performed a search
  int topK = 10; // Default value

  List<int> get resultId => results.map((e) => e.id).toList();

  @override
  void initState() {
    super.initState();
    _loadAllResearch(); // Load all research on initial load
  }

  // New method to load all research items
  // New method to load all research items
  void _loadAllResearch() async {
    setState(() {
      isLoading = true;
    });

    try {
      final data = await supabase
          .from('view_research_main_with_vector')
          .select('id, title')
          .order('id', ascending: true); // Order by most recent first

      setState(() {
        results = (data as List<dynamic>)
            .map(
              (e) => ResearchModel.fromJson({
                'id': e['id'],
                'title': e['title'],
                'score': null, // No score for initial load
              }),
            )
            .toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load research: $e')));
    }
  }

  void _performSearch() async {
    String query = _controller.text.trim();
    if (query.isEmpty) return;

    setState(() {
      isLoading = true;
      results = [];
      hasSearched = true; // Mark that a search has been performed
    });

    try {
      Map<String, dynamic> searchResult = await searchWithDebug(
        query,
        topK: topK,
      );

      setState(() {
        results = (searchResult['results'] as List<Map<String, dynamic>>)
            .map((e) => ResearchModel.fromJson(e))
            .toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('An error occured: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          "BioSat Explorer",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.info),
          onPressed: () {
            const githubUrl =
                "https://github.com/jgalazka/SB_publications/blob/main/SB_publication_PMC.csv";

            showDialog(
  context: context,
  builder: (context) {
    int selectedIndex = 0; // 0 = About App, 1 = Disclaimer

    return StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          title: const Text(
            "BioSat Explorer Info",
            style: TextStyle(
              color: Colors.blueAccent, // Blue accent title
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // NASA logo
                Image.asset('assets/nasa_logo.png', height: 80),
                const SizedBox(height: 16),

                // Segmented Buttons
                SegmentedButton<int>(
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith<Color?>(
                      (states) => states.contains(WidgetState.selected)
                          ? Colors.blueAccent.withOpacity(0.2)
                          : Colors.transparent,
                    ),
                    side: WidgetStateProperty.all(
                      const BorderSide(color: Colors.blueAccent),
                    ),
                    foregroundColor: WidgetStateProperty.resolveWith<Color>(
                      (states) => states.contains(WidgetState.selected)
                          ? Colors.blueAccent
                          : Colors.black87,
                    ),
                  ),
                  segments: const [
                    ButtonSegment<int>(
                      value: 0,
                      label: Text("About App"),
                      icon: Icon(Icons.info_outline),
                    ),
                    ButtonSegment<int>(
                      value: 1,
                      label: Text("Disclaimer & Copyright"),
                      icon: Icon(Icons.policy_outlined),
                    ),
                  ],
                  selected: {selectedIndex},
                  onSelectionChanged: (newSelection) {
                    setState(() {
                      selectedIndex = newSelection.first;
                    });
                  },
                ),

                const SizedBox(height: 16),

                // Dynamic content
                if (selectedIndex == 0)
                  const Text(
                    "BioSat Explorer allows you to search research articles using semantic search powered by Google's Gemini model and Supabase vector database.\n\n"
                    "It has been created by the Arsman team from Iraqi Kurdistan, and the research data is licensed by NASA, available on GitHub.",
                    textAlign: TextAlign.center,
                  )
                else
                  const Text(
                    "Data & Copyright Notice\n\n"
                    "BioSat Explorer uses publicly available data provided by the National Aeronautics and Space Administration (NASA).\n"
                    "NASA material is not subject to copyright protection in the United States (Title 17, U.S.C., §105).\n"
                    "However, the data and content presented here have been processed and visualized for educational and informational purposes by the Arsman team.\n\n"
                    "Disclaimer:\n"
                    "This application is not endorsed by NASA. The use of NASA data does not imply any affiliation with or endorsement by NASA or the U.S. Government.\n"
                    "While we strive for accuracy, this application and its data are provided “as is” without warranty of any kind.",
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final Uri url = Uri.parse(githubUrl);
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Could not open the GitHub link'),
                    ),
                  );
                }
              },
              child: const Text(
                "Open GitHub",
                style: TextStyle(color: Colors.blueAccent),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Close",
                style: TextStyle(color: Colors.blueAccent),
              ),
            ),
          ],
        );
      },
    );
  },
);


          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Search row with input, topK dropdown, and search button
            Row(
              children: [
                // Search input field
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      labelText: "Search for something...",
                      labelStyle: TextStyle(color: Colors.blueAccent),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.blueAccent.shade200,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.blueAccent.shade100,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.blueAccent,
                          width: 2,
                        ),
                      ),
                      suffixIcon: _controller.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, color: Colors.blueAccent),
                              onPressed: () {
                                _controller.clear();
                                setState(() {
                                  hasSearched = false;
                                });
                                _loadAllResearch();
                              },
                            )
                          : null,
                      prefixIcon: Icon(Icons.search, color: Colors.blueAccent),
                      contentPadding: EdgeInsets.symmetric(vertical: 13),
                    ),
                    onSubmitted: (_) => _performSearch(),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                SizedBox(width: 8),

                // Search Button
                SizedBox(
                  width: 120,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: isLoading ? null : _performSearch,
                    icon: isLoading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(Icons.search, color: Colors.white, size: 20),
                    label: Text(
                      isLoading ? "..." : "Search",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),

                SizedBox(width: 8),

                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.blueAccent.shade200),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blueAccent.withOpacity(0.05),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: topK,
                      icon: Icon(
                        Icons.arrow_drop_down,
                        color: Colors.blueAccent,
                      ),
                      style: TextStyle(
                        color: Colors.blueAccent.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                      items: [5, 10, 20].map((int value) {
                        return DropdownMenuItem<int>(
                          value: value,
                          child: Text('Top $value'),
                        );
                      }).toList(),
                      onChanged: (int? newValue) {
                        if (newValue != null) {
                          setState(() {
                            topK = newValue;
                          });
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),

            // Results section
            if (results.isEmpty && !isLoading)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.blueAccent.shade200,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        hasSearched
                            ? "No results found"
                            : "No research available",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        hasSearched
                            ? "Try a different query"
                            : "Start by searching",
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (results.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            hasSearched
                                ? "${results.length} results found"
                                : "${results.length} research items",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: results.length,
                        itemBuilder: (_, index) {
                          final ResearchModel item = results[index];
                          final score = item.score;

                          Color scoreColor = Colors.blue;
                          if (score != null) {
                            if (score > 0.7) {
                              scoreColor = Colors.green;
                            } else if (score > 0.5) {
                              scoreColor = Colors.orange;
                            } else {
                              scoreColor = Colors.red;
                            }
                          }

                          return Card(
                            margin: EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            shadowColor: Colors.blueAccent.withOpacity(0.1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: Colors.blueAccent.withOpacity(0.1),
                                width: 1,
                              ),
                            ),
                            color: Colors.white,
                            child: ListTile(
                              onTap: () {
                                context
                                    .read<SupabaseSingleResearchProvider>()
                                    .setResearch(item);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ResearchScreen(research_id: item.id),
                                  ),
                                );
                              },
                              contentPadding: EdgeInsets.all(16),
                              leading: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      scoreColor.withOpacity(0.2),
                                      scoreColor.withOpacity(0.1),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: scoreColor.withOpacity(0.3),
                                    width: 2,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    "#${index + 1}",
                                    style: TextStyle(
                                      color: scoreColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                              title: Text(
                                item.title ?? "No Title",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color: Colors.grey.shade800,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: score != null
                                  ? Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 5,
                                            ),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  scoreColor.withOpacity(0.2),
                                                  scoreColor.withOpacity(0.1),
                                                ],
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              border: Border.all(
                                                color: scoreColor.withOpacity(
                                                  0.3,
                                                ),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.verified,
                                                  size: 14,
                                                  color: scoreColor,
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  "${(score * 100).toStringAsFixed(1)}% match",
                                                  style: TextStyle(
                                                    color: scoreColor,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : null,
                              trailing: Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blueAccent,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.arrow_forward_ios,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  double cosineSimilarity(List<double> a, List<double> b) {
    double dot = 0;
    for (int i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
    }
    return dot;
  }

  final SupabaseClient supabase = SupabaseClient(SUPABASE_URL, SUPABASE_KEY);

  static const String SUPABASE_URL = "https://rvxkdsrryfpkvdzzkmnm.supabase.co";
  static const String SUPABASE_KEY =
      "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ2eGtkc3JyeWZwa3ZkenprbW5tIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkxODE5OTUsImV4cCI6MjA3NDc1Nzk5NX0._ylejG3TbqCbjRvZcgimG-TD8yiE-gkHR_3cpnfvJrY";
  static const String GEMINI_API_KEY =
      "AIzaSyBjF6ZQv2cSii64Ij7dAXzcImCiqUeKqKQ";
  static const String EMBEDDING_MODEL = "gemini-embedding-001";

  Future<List<double>> embedQuery(String query) async {
    final url = Uri.parse(
      "https://generativelanguage.googleapis.com/v1beta/models/$EMBEDDING_MODEL:embedContent?key=$GEMINI_API_KEY",
    );

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "content": {
          "parts": [
            {"text": query},
          ],
        },
        "taskType": "RETRIEVAL_QUERY",
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      List<dynamic> values = data['embedding']['values'];
      return normalizeVector(values.map((e) => (e as num).toDouble()).toList());
    } else {
      throw Exception("Embedding failed: ${response.body}");
    }
  }

  Future<List<Map<String, dynamic>>> getVectors({
    bool forceRefresh = false,
  }) async {
    final data =
        await supabase.from('view_research_main_with_vector').select()
            as List<dynamic>;
    if (data.isEmpty) throw Exception('No data returned');
    List<Map<String, dynamic>> result = [];
    for (var row in data) {
      int id = row['id'];
      String title = row['title'];
      var embeddingData = row['vector_whole_content'];
      List<double> vector;
      if (embeddingData is String) {
        List<dynamic> parsed = jsonDecode(embeddingData);
        vector = parsed.map((e) => (e as num).toDouble()).toList();
      } else if (embeddingData is List) {
        vector = embeddingData.map((e) => (e as num).toDouble()).toList();
      } else {
        throw Exception('Unexpected vector_whole_content format for ID $id');
      }
      vector = normalizeVector(vector);
      result.add({'id': id, 'title': title, 'vector': vector});
    }
    return result;
  }

  Future<List<Map<String, dynamic>>> search(
    String query, {
    int topK = 30,
  }) async {
    if (query.trim().isEmpty) return [];
    List<double> queryVec = await embedQuery(query);
    List<Map<String, dynamic>> vectorData = await getVectors();
    List<Map<String, dynamic>> results = [];
    double threshold = 0.3;

    for (var item in vectorData) {
      int id = item['id'];
      String title = item['title'];
      List<double> vec = item['vector'];
      double score = cosineSimilarity(queryVec, vec);
      if (score >= threshold) {
        results.add({"id": id, "title": title, "score": score});
      }
    }

    results.sort((a, b) => b['score'].compareTo(a['score']));
    return results.take(topK).toList();
  }

  Future<Map<String, dynamic>> searchWithDebug(
    String query, {
    int topK = 30,
  }) async {
    if (query.trim().isEmpty) {
      return {
        "results": [],
        "debug": {"error": "Empty query"},
      };
    }
    List<double> queryVec = await embedQuery(query);
    List<Map<String, dynamic>> vectorData = await getVectors();
    List<Map<String, dynamic>> results = [];
    double minScore = double.infinity;
    double maxScore = double.negativeInfinity;
    double sumScore = 0;
    int count = 0;

    for (var item in vectorData) {
      int id = item['id'];
      String title = item['title'];
      List<double> vec = item['vector'];
      double score = cosineSimilarity(queryVec, vec);
      results.add({"id": id, "title": title, "score": score});
      minScore = min(minScore, score);
      maxScore = max(maxScore, score);
      sumScore += score;
      count++;
    }

    results.sort((a, b) => b['score'].compareTo(a['score']));
    return {
      "results": results.take(topK).toList(),
      "debug": {
        "total_vectors": count,
        "min_score": minScore,
        "max_score": maxScore,
        "avg_score": sumScore / count,
        "query_vec_length": queryVec.length,
      },
    };
  }

  List<double> normalizeVector(List<double> vec) {
    double norm = sqrt(vec.fold(0, (sum, x) => sum + x * x));
    if (norm == 0) return vec;
    return vec.map((x) => x / norm).toList();
  }
}
