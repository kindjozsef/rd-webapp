package ro.kindjozsef.rd.webapp.controller

import org.springframework.stereotype.Controller
import org.springframework.ui.Model
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PathVariable
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RequestParam
import ro.kindjozsef.rd.webapp.persistence.domain.Student
import ro.kindjozsef.rd.webapp.persistence.repository.StudentRepository

@Controller
@RequestMapping(path = ["/students"])
class StudentController(
    private val studentRepository: StudentRepository
) {

    @GetMapping
    fun getAllStudents(model: Model): String {
        val studentsFromDB = studentRepository.findAll()
        model.addAttribute("students", studentsFromDB)
        return "students";
    }

    @PostMapping("/create")
    fun createStudent(@RequestParam firstname: String, @RequestParam lastname: String): String {
        val student = Student(
            firstName = firstname,
            lastName = lastname
        )
        studentRepository.save(student)
        return "redirect:/students"
    }

    @PostMapping("/delete/{id}")
    fun deleteById(@PathVariable id: Long): String {
        studentRepository.deleteById(id)
        return "redirect:/students"
    }

}