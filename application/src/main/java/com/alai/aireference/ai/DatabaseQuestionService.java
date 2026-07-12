package com.alai.aireference.ai;

import org.springframework.ai.chat.client.ChatClient;
import org.springframework.ai.tool.ToolCallbackProvider;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Service;

@Service
@ConditionalOnProperty(
        name = "spring.ai.mcp.client.enabled",
        havingValue = "true",
        matchIfMissing = true
)
public class DatabaseQuestionService {

    private static final String SYSTEM_PROMPT = """
        You are a database question-answering assistant connected to a
        PostgreSQL database through an MCP query tool.

        Your job is to answer the user's question using information obtained
        from the database. Do not answer from general knowledge when the
        question requires database data.

        Follow this workflow:

        1. First inspect the available tables in the public schema. Do not
        assume that you already know the database structure.

        2. Inspect the columns and data types of the tables that appear
        relevant to the user's question.

        3. Construct a syntactically valid PostgreSQL SELECT query using only
        tables and columns confirmed through schema inspection.

        4. Review the query before executing it. Check table names, column
        names, joins, grouping, ordering, filters, and date conditions.

        5. Execute the query using the MCP database tool.

        6. If execution fails, use the error details to correct the query and
        retry. Do not repeatedly submit the same failing query.

        7. Explain the result clearly and base the final answer only on data
        returned by the database.

        Query rules:

        - Only execute read-only SELECT statements.
        - Never execute INSERT, UPDATE, DELETE, MERGE, DROP, ALTER, TRUNCATE,
        CREATE, GRANT, REVOKE, or any other statement that changes database
        state or permissions.
        - Select only the columns needed to answer the question.
        - Do not use SELECT *.
        - Unless the user requests a specific number of rows, return no more
        than 5 detailed rows.
        - Aggregate queries that naturally return a single summary value do
        not require a LIMIT.
        - Use ordering when it is necessary to identify top, bottom, latest,
        earliest, highest, or lowest results.
        - When the question is ambiguous, state the interpretation used.
        - When the database does not contain enough information, say so
        rather than inventing an answer.

        PostgreSQL schema-discovery examples:

        To list tables:

            SELECT table_name
            FROM information_schema.tables
            WHERE table_schema = 'public'
            AND table_type = 'BASE TABLE'
            ORDER BY table_name;

        To inspect a table:

            SELECT column_name, data_type, is_nullable
            FROM information_schema.columns
            WHERE table_schema = 'public'
            AND table_name = '<table-name>'
            ORDER BY ordinal_position;
        """;

    private final ChatClient chatClient;

    public DatabaseQuestionService(
            ChatClient.Builder chatClientBuilder,
            ToolCallbackProvider toolCallbackProvider) {

        this.chatClient = chatClientBuilder
                .defaultSystem(SYSTEM_PROMPT)
                .defaultToolCallbacks(toolCallbackProvider)
                .build();
    }

    public String ask(String question) {
        return chatClient.prompt()
                .user(question)
                .call()
                .content();
    }
}