package com.fitlife.fitnesscrm.domain.useCases.staff;

import com.fitlife.fitnesscrm.domain.entities.Staff;
import com.fitlife.fitnesscrm.domain.protocols.staff.StaffProtocol;
import org.springframework.stereotype.Service;

import java.util.Optional;

@Service
public class StaffFindByUsernameUseCase {
    private final StaffProtocol staffProtocol;

    public StaffFindByUsernameUseCase(StaffProtocol staffProtocol) {
        this.staffProtocol = staffProtocol;
    }

    public Optional<Staff> execute(String username) {
        return staffProtocol.findByUsername(username);
    }
}