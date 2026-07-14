package com.alai.modelvalidator;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class ValidationController {

    private final ToolCallingValidator validator;

    public ValidationController(ToolCallingValidator validator) {
        this.validator = validator;
    }

    @GetMapping("/api/validate-tool-calling")
    public ToolCallingValidator.ValidationResult validate() {
        return validator.validate();
    }
}