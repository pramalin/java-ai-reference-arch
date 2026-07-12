package com.alai.aireference.api;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api")
public class ApplicationController {

    @GetMapping("/info")
    public ApplicationInfo info() {
        return new ApplicationInfo(
                "Java AI Reference Architecture",
                "UP",
                "0.1.0-SNAPSHOT"
        );
    }
}