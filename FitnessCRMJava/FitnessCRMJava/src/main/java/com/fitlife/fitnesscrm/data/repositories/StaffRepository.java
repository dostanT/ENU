package com.fitlife.fitnesscrm.data.repositories;

import com.fitlife.fitnesscrm.domain.entities.Staff;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface StaffRepository extends JpaRepository<Staff, Integer>{

    public Optional<Staff> findByUsername(String username);
}