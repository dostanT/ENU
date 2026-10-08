package com.fitlife.fitnesscrm.data.dataSources;

import com.fitlife.fitnesscrm.domain.entities.Staff;
import com.fitlife.fitnesscrm.domain.useCases.staff.StaffFindByUsernameUseCase;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;

public class StaffUserDetailService implements UserDetailsService {
    private final StaffFindByUsernameUseCase staffFindByUsernameUseCase;

    public StaffUserDetailService(StaffFindByUsernameUseCase staffFindByUsernameUseCase) {
        this.staffFindByUsernameUseCase = staffFindByUsernameUseCase;
    }

    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        Staff staff = staffFindByUsernameUseCase.execute(username)
                .orElseThrow(() -> new UsernameNotFoundException("User not found 0loadUserByName0: " + username));
        return User.withUsername(staff.getUsername())
                .password(staff.getPasswordHash())
                .roles(staff.getRole().name())
                .disabled(!staff.getActive())
                .build();
    }
}