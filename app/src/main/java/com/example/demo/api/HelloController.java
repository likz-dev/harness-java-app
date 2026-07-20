package com.example.demo.api;

import com.example.demo.config.AppInfo;
import java.util.LinkedHashMap;
import java.util.Map;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api")
public class HelloController {

  private final AppInfo appInfo;

  public HelloController(AppInfo appInfo) {
    this.appInfo = appInfo;
  }

  @GetMapping("/hello")
  public Map<String, String> hello() {
    Map<String, String> body = new LinkedHashMap<>();
    body.put("message", "Hello from " + appInfo.getName());
    body.put("version", appInfo.getVersion());
    body.put("color", appInfo.getColor());
    return body;
  }

  @GetMapping("/version")
  public Map<String, String> version() {
    Map<String, String> body = new LinkedHashMap<>();
    body.put("name", appInfo.getName());
    body.put("version", appInfo.getVersion());
    body.put("color", appInfo.getColor());
    return body;
  }
}
