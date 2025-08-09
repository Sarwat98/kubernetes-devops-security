// package com.devsecops;
// import org.springframework.context.annotation.Configuration;
// import org.springframework.http.HttpHeaders;
// import org.springframework.security.config.annotation.web.builders.HttpSecurity;
// import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
// import org.springframework.security.config.annotation.web.configuration.WebSecurityConfigurerAdapter;

// @Configuration
// @EnableWebSecurity
// public class WebSecurityConfig extends WebSecurityConfigurerAdapter {

//     @Override
//     protected void configure(HttpSecurity http) throws Exception {
//         http
//             .headers()
//             .defaultsDisabled()
//             .addHeaderWriter((request, response) -> 
//                 response.addHeader("X-Content-Type-Options", "nosniff")) // Use string header name directly
//             .and()
//             .csrf().disable() // Disable CSRF protection
//             .httpBasic(); // Basic auth, if you're using it
//     }
// }
