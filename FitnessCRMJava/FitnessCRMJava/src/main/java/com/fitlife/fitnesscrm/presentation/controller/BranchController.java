package com.fitlife.fitnesscrm.presentation.controller;

import com.fitlife.fitnesscrm.domain.useCases.branch.BranchFindAllOrderByCodeUseCase;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

@Controller
public class BranchController {
    private final BranchFindAllOrderByCodeUseCase branchFindAllOrderByCodeUseCase;

    public BranchController(BranchFindAllOrderByCodeUseCase branchFindAllOrderByCodeUseCase) {
        this.branchFindAllOrderByCodeUseCase = branchFindAllOrderByCodeUseCase;
    }

    @GetMapping("/branches")
    public String list(Model model) {
        model.addAttribute("branches", branchFindAllOrderByCodeUseCase.execute());
        return "branches/list";
    }

    @GetMapping("/")
    public String root() {
        return "redirect:/branches";
    }
}