package com.example.urgs_api.metadata.service;

import com.example.urgs_api.metadata.dto.RegElementMaintenanceDTO;

public interface RegElementMaintenanceService {

    boolean maintain(RegElementMaintenanceDTO request, String operator);
}
