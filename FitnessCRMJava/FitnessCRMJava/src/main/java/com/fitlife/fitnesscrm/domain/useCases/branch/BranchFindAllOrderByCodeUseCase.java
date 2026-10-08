package com.fitlife.fitnesscrm.domain.useCases.branch;

import com.fitlife.fitnesscrm.domain.entities.Branch;
import com.fitlife.fitnesscrm.domain.protocols.branch.BranchProtocol;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class BranchFindAllOrderByCodeUseCase {
    private final BranchProtocol branchProtocol;

    public BranchFindAllOrderByCodeUseCase(BranchProtocol branchProtocol) {
        this.branchProtocol = branchProtocol;
    }

    public List<Branch> execute() {
        return branchProtocol.findAllOrderByCode();
    }
}