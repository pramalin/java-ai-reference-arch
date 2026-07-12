package com.alai.aireference.api;

import com.alai.aireference.ai.DatabaseQuestionService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import org.springframework.web.bind.annotation.*;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;

@RestController
@RequestMapping("/api/questions")
@ConditionalOnProperty(
        name = "spring.ai.mcp.client.enabled",
        havingValue = "true",
        matchIfMissing = true
)
public class QuestionController {

    private final DatabaseQuestionService questionService;

    public QuestionController(DatabaseQuestionService questionService) {
        this.questionService = questionService;
    }

    @PostMapping
    public QuestionResponse ask(@Valid @RequestBody QuestionRequest request) {
        return new QuestionResponse(
                request.question(),
                questionService.ask(request.question())
        );
    }

    public record QuestionRequest(@NotBlank String question) {
    }

    public record QuestionResponse(String question, String answer) {
    }
}