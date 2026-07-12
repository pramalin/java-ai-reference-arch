### Architecture Decision Record
- Project Structure
The project is modeled after this Langgraph exampe https://github.com/docker/compose-for-agents/tree/main/langgraph

We'll keep the infrastructure the same but replace the python modules with Java.

The example shows how it processes a natural language query such as "Which sales agent made the most in sales in 2009?" by determining a suitable SQL query against the local database, examining the table structures. 

We will do this step by step milestones outlined in the README.md



java-ai-reference-arch/
|
|-- README.md
|-- compose.yaml
|-- compose.openai.yaml
|-- mcp-config.yaml
|-- .env
|
|-- docs/
|   |-- architecture.md
|   |-- decisions/
|   |   |-- ADR-0001-project-structure.md
|   |   |-- ADR-0002-llm-provider.md
|   |   |-- ...
|   | diagrams/
|
|-- gateway/
|
|-- angular-ui/
|
|-- database/

