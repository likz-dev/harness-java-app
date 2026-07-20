package com.example.demo.api;

import static org.hamcrest.Matchers.is;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.web.servlet.MockMvc;

@SpringBootTest
@AutoConfigureMockMvc
class HelloControllerTest {

  @Autowired
  private MockMvc mockMvc;

  @Test
  void helloReturnsMessageVersionAndColor() throws Exception {
    mockMvc
        .perform(get("/api/hello"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.message", is("Hello from Sample Java App")))
        .andExpect(jsonPath("$.version", is("1.0.0")))
        .andExpect(jsonPath("$.color", is("blue")));
  }

  @Test
  void versionReturnsAppMetadata() throws Exception {
    mockMvc
        .perform(get("/api/version"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.name", is("Sample Java App")))
        .andExpect(jsonPath("$.version", is("1.0.0")))
        .andExpect(jsonPath("$.color", is("blue")));
  }
}
