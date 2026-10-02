package com.example.demo.service;

import com.example.demo.model.Task;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.atomic.AtomicLong;

@Service
public class TaskService {

    private final List<Task> tasks = new ArrayList<>();
    private final AtomicLong nextId = new AtomicLong(1);

    public TaskService() {
        tasks.add(new Task(nextId.getAndIncrement(), "Learn Spring Boot", false));
        tasks.add(new Task(nextId.getAndIncrement(), "Build a REST API", false));
    }

    public List<Task> findAll() {
        return tasks;
    }

    public Task findById(Long id) {
        return tasks.stream()
                .filter(task -> task.getId().equals(id))
                .findFirst()
                .orElse(null);
    }
    public Task create(Task task) {
        task.setId(nextId.getAndIncrement());
        tasks.add(task);
        return task;
    }
}