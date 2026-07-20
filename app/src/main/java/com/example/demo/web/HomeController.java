package com.example.demo.web;

import com.example.demo.config.AppInfo;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

@Controller
public class HomeController {

  private final AppInfo appInfo;

  public HomeController(AppInfo appInfo) {
    this.appInfo = appInfo;
  }

  @GetMapping("/")
  public String home(Model model) {
    model.addAttribute("appName", appInfo.getName());
    model.addAttribute("version", appInfo.getVersion());
    model.addAttribute("color", appInfo.getColor());
    model.addAttribute("accentHex", appInfo.getAccentHex());
    return "index";
  }
}
