package com.example.demo.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

@Component
public class AppInfo {

  private final String name;
  private final String version;
  private final String color;

  public AppInfo(
      @Value("${app.name}") String name,
      @Value("${app.version}") String version,
      @Value("${app.color}") String color) {
    this.name = name;
    this.version = version;
    this.color = color;
  }

  public String getName() {
    return name;
  }

  public String getVersion() {
    return version;
  }

  public String getColor() {
    return color;
  }

  /** CSS-safe hex (or named color) derived from the configured color token. */
  public String getAccentHex() {
    switch (color.toLowerCase()) {
      case "green":
        return "#3dd68c";
      case "amber":
      case "yellow":
        return "#f5a524";
      case "red":
        return "#f31260";
      case "teal":
        return "#14c4c4";
      case "blue":
      default:
        return "#4da3ff";
    }
  }
}
