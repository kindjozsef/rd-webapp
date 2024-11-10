package ro.kindjozsef.rd.webapp.controller

import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PathVariable
import org.springframework.web.bind.annotation.RestController

@RestController
class HelloWorldController {


    @GetMapping(path = ["/hello/{name}"])
    fun sayHello(@PathVariable name: String): String {
        return "Hello $name"
    }

}