package ro.kindjozsef.rd.webapp.persistence.domain

import jakarta.persistence.*

@Entity
data class Student(
    @field:Id
    @field:GeneratedValue(strategy = GenerationType.IDENTITY)
    var id: Long? = null,
    @field:Column(name = "first_name")
    val firstName: String,
    @field:Column(name = "last_name")
    val lastName: String,
)