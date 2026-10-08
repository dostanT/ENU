package com.fitlife.fitnesscrm.domain.protocols.branch;

import com.fitlife.fitnesscrm.domain.entities.Branch;

import java.util.List;

public interface BranchProtocol {
    public List<Branch> findAllOrderByCode();
}