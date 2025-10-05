# BioSat Explorer

A Flutter-based research article exploration app that enables semantic search and AI-powered analysis of scientific publications using Google's Gemini AI and Supabase vector database.

Exploring research papers provided by NASA containing space experiments that affect the journey towards going to Moon and Mars.

### Try Here: 🔗 [BioSat Explorer Web App](https://biosat-explorer.vercel.app/) 
  
![NASA Logo](https://github.com/user-attachments/assets/f2a94b39-fbdc-40b5-9ccf-cc812cb3a2b4)
<!-- 
<img width="1665" height="1393" alt="Image" src="https://github.com/user-attachments/assets/f2a94b39-fbdc-40b5-9ccf-cc812cb3a2b4"/> -->




## 🌟 Features

### 🔍 Semantic Search
- **AI-Powered Search**: Uses Google's Gemini embedding model for semantic search
- **Vector Database**: Leverages Supabase for efficient vector similarity search
- **Top-K Results**: Configurable number of search results (5, 10, 20)
- **Relevance Scoring**: Visual similarity scores with color-coded indicators

### 📚 Research Content
- **Full Research Articles**: Access complete research content from NASA publications
- **Multiple View Modes**: 
  - Original content
  - AI-generated summaries
  - Interactive knowledge graphs
- **Font Size Control**: Adjustable text size for better readability
- **External Links**: Direct access to source URLs

### 🤖 AI-Powered Analysis
- **Smart Summarization**: Generate comprehensive summaries using Gemini AI
- **Knowledge Graphs**: Visual representation of research concepts and relationships
- **Structured Output**: JSON-formatted knowledge graphs with nodes and relations
- **Research Insights**: Identify progress, gaps, consensus, and actionable information

### 🎨 User Experience
- **Responsive Design**: Optimized for various screen sizes
- **Modern UI**: Clean, professional interface with NASA branding
- **Loading States**: Smooth loading indicators and error handling
- **Accessibility**: Font scaling and clear visual hierarchy

<br>
<br>

# 📱 Usage Guide

## 🔍 Basic Search
- 📝 Enter your research query in the search bar  
- 🔢 Select the number of results (**Top K:** 5, 10, or 20)  
- 🎨 View relevance-scored results with color-coded indicators  
- 📄 Click on articles to explore detailed content  

## 📖 Article Exploration
- 📜 **Original Content:** Read the full research article with adjustable font size  
- 🤖 **AI Summary:** Generate and read AI-powered summaries with structured formatting  
- 🧠 **Knowledge Graph:** Interactive visualization of research concepts and relationships  
- 🌐 **External Sources:** Direct access to original publication URLs  

## ⚙️ Advanced Features
- 🔎 **Font Size Control:** Adjust text size for comfortable reading in original and summary views  
- 🔀 **View Mode Switching:** Use segmented controls to switch between content modes  
- 🔗 **Related Articles:** Explore similar articles and citations  
- 📊 **Research Analysis:** AI-powered insights into research trends and patterns  


## 📂 Dataset Used

For this project, we used a dataset of scientific publications compiled in a public CSV:

- **Dataset source**: [SB_publication_PMC.csv (GitHub)](https://github.com/jgalazka/SB_publications/blob/main/SB_publication_PMC.csv)  
- **Description**: This CSV contains a curated list of research articles (PubMed Central publications), including metadata and identifiers for use in semantic search and analysis.  

⚠️ **Note:** The dataset contains some **duplicate URLs**, which should be handled during preprocessing to avoid redundant entries in the database.




## 🔒 Privacy & Data  

### Data Sources  
- NASA publicly available research data  
- Processed and visualized for educational purposes  
- No copyright restrictions (NASA material - Title 17, U.S.C., §105)  

### API Usage  
- Google Gemini API for AI features  
- Supabase for data storage and vector operations  
- All processing happens client-side where possible  

---

## 📄 License & Attribution  

### Data License  
- **NASA research data:** Public domain (Title 17, U.S.C., §105)  
- **Application code:** open to contribute, and submit PRs.

### Disclaimer  
This application is **not endorsed by NASA**.  
The use of NASA data does not imply any affiliation with or endorsement by NASA or the U.S. Government.  


## Support
 - For issues and questions, please contact:  
📧 **[Email](mailto:alandkawaali@gmail.com)**  
