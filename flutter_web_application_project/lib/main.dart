import 'package:biosat_explorer/providers/search_parts_provider.dart';
import 'package:biosat_explorer/providers/supabase_single_research_provider.dart';
import 'package:biosat_explorer/screens/semantic_search_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://rvxkdsrryfpkvdzzkmnm.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ2eGtkc3JyeWZwa3ZkenprbW5tIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkxODE5OTUsImV4cCI6MjA3NDc1Nzk5NX0._ylejG3TbqCbjRvZcgimG-TD8yiE-gkHR_3cpnfvJrY',
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SearchPartsProvider()),
        ChangeNotifierProvider(create: (_) => SupabaseSingleResearchProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Research Articles',
        home: Consumer<SupabaseSingleResearchProvider>(
          builder: (context, srp, _) {
            if (srp.isLoading) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            return SemanticSearchScreen();
          },
        ),
      ),
    ),
  );
}