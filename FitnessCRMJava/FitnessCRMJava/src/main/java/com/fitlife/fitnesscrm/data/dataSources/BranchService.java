package com.fitlife.fitnesscrm.data.dataSources;

import com.fitlife.fitnesscrm.data.repositories.BranchRepository;
import com.fitlife.fitnesscrm.domain.entities.Branch;
import com.fitlife.fitnesscrm.domain.protocols.branch.BranchProtocol;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class BranchService implements BranchProtocol {
    private final BranchRepository branchRepository;

    public BranchService(BranchRepository branchRepository){
        this.branchRepository = branchRepository;
    }

    public List<Branch> findAllOrderByCode() {
        return branchRepository.findAll()
                .stream()
                .sorted((a,b) -> a.getCode().compareTo(b.getCode()))
                .toList();
    }
}