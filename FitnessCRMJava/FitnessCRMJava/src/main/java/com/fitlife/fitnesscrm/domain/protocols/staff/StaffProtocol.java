package com.fitlife.fitnesscrm.domain.protocols.staff;

import com.fitlife.fitnesscrm.domain.entities.Staff;

import java.util.Optional;

public interface StaffProtocol {
    public Optional<Staff> findByUsername(String username);
}