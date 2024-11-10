package ro.kindjozsef.rd.webapp.persistence.repository

import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.stereotype.Repository
import ro.kindjozsef.rd.webapp.persistence.domain.Student

@Repository
interface StudentRepository: JpaRepository<Student, Long> {
}