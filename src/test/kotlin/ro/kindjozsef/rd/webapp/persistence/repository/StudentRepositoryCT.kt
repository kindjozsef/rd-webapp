package ro.kindjozsef.rd.webapp.persistence.repository

import org.assertj.core.api.Assertions.assertThat
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import ro.kindjozsef.rd.webapp.BaseComponentTest
import ro.kindjozsef.rd.webapp.persistence.domain.Student

class StudentRepositoryCT: BaseComponentTest() {


    @Autowired
    private lateinit var underTest: StudentRepository

    @Test
    fun `test that auto increment and schema creation work`() {
        // given
        val aStudent = Student(
            firstName = "Jozsef",
            lastName = "Kind"
        )

        // when
        val persistedStudent = underTest.save(aStudent)

        assertThat(persistedStudent.id).isNotNull

        // and we can fetch the user from the db too
        val fetchedStudent = underTest.findById(persistedStudent.id!!)

        assertThat(fetchedStudent).isPresent
        assertThat(fetchedStudent.get().firstName).isEqualTo(aStudent.firstName)
        assertThat(fetchedStudent.get().lastName).isEqualTo(aStudent.lastName)
    }

}