package com.fitlife.fitnesscrm.data.dataSources;

import com.fitlife.fitnesscrm.data.repositories.StaffRepository;
import com.fitlife.fitnesscrm.domain.entities.Staff;
import com.fitlife.fitnesscrm.domain.protocols.staff.StaffProtocol;
import org.springframework.stereotype.Service;

import java.util.Optional;

@Service
public class StaffService implements StaffProtocol {
    private final StaffRepository staffRepository;

    public StaffService(StaffRepository staffRepository){
        this.staffRepository = staffRepository;
    }

    public Optional<Staff> findByUsername(String username) {
        return staffRepository.findByUsername(username);
    }
}