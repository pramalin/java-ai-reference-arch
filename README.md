### Java AI Reference Architecture
The plan is to build the project as a series of milestones:

1. Baseline
    - Docker Compose
    - Angular
    - Spring Boot
    - Existing sample database
    - End-to-end request/response

2. Natural Language → SQL
    - Spring AI
    - Database schema discovery
    - Tool calling
    - Read-only SQL execution
    - Display generated SQL alongside the answer

3. Production-quality architecture
    - Clear service boundaries
    - Prompt templates
    - Conversation history
    - Error handling
    - Configuration
    - Logging and observability

4. Second agent
    - Validation/review
    - Result interpretation
    - Retry/refinement when SQL is poor
    - Agent orchestration

5. Enterprise features
    - Authentication
    - Role-based permissions
    - Audit trail
    - Streaming responses
    - Multiple LLM providers
    - AWS deployment
    - Metrics and tracing
