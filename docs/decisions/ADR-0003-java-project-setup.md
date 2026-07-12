### Java project setup

https://start.spring.io/

Project: Maven
Language: Java
Java: 26
Packaging: Jar

Group: com.alai
Artifact: ai-reference
Name: ai-reference
Package: com.alai.aireference


Initial dependencies:
Spring Web
Spring Boot Actuator

- verified that the vanilla Spring project compiles.

- Added /info endpoint

```java
package com.alai.aireference.api;

public record ApplicationInfo(
        String name,
        String status,
        String version
) {
}
```

```java
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
```

Expected result:
```json
{
  "name": "Java AI Reference Architecture",
  "status": "UP",
  "version": "0.1.0-SNAPSHOT"
}
```

The official guide uses a Java record for the JSON representation and @RestController with @GetMapping, so this remains directly aligned with the tutorial while giving us a project-relevant endpoint.

A clean repository structure at this stage would be:

java-ai-reference-arch/
├── compose.yaml
├── compose.openai.yaml
├── README.md
├── docs/
└── application/
    ├── pom.xml
    ├── mvnw
    ├── mvnw.cmd
    ├── .mvn/
    └── src/

I prefer application/ or backend/ over gateway/ at this point. The service will initially contain the REST API, Spring AI orchestration, database tools, and application logic. Calling it a gateway could imply that it is only an edge-routing component.

Before adding a Dockerfile, verify it locally:
```sh
cd application
./mvnw spring-boot:run
```
Then test:
```sh
curl http://localhost:8080/api/info
curl http://localhost:8080/actuator/health
```

- verified the info endpoint.
```sh
~/work/java-ai-reference-arch/application$ curl http://localhost:8080/api/info
{"name":"Java AI Reference Architecture","status":"UP","version":"0.1.0-SNAPSHOT"}

~/work/java-ai-reference-arch/application$ curl http://localhost:8080/actuator/health
{"groups":["liveness","readiness"],"status":"UP"}
```