package com.example.urgs_api.org.controller;

import com.example.urgs_api.org.dto.OrgDTO;
import com.example.urgs_api.org.dto.OrgRequest;
import com.example.urgs_api.org.model.Org;
import com.example.urgs_api.org.service.OrgService;
import org.springframework.http.ResponseEntity;
import org.springframework.util.StringUtils;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/orgs")
public class OrgController {

    private final OrgService orgService;

    public OrgController(OrgService orgService) {
        this.orgService = orgService;
    }

    @GetMapping
    public List<OrgDTO> list(@RequestParam(value = "keyword", required = false) String keyword) {
        List<Org> list;
        if (StringUtils.hasText(keyword)) {
            list = orgService.lambdaQuery()
                    .like(Org::getName, keyword)
                    .or()
                    .like(Org::getCode, keyword)
                    .list();
        } else {
            list = orgService.list();
        }
        return list.stream().map(OrgDTO::fromEntity).collect(Collectors.toList());
    }

    @PostMapping
    public OrgDTO create(@RequestBody OrgRequest req) {
        Org org = toEntity(req, null);
        orgService.save(org);
        return OrgDTO.fromEntity(org);
    }

    @PutMapping("/{id}")
    public ResponseEntity<OrgDTO> update(@PathVariable("id") Long id, @RequestBody OrgRequest req) {
        Org existing = orgService.getById(id);
        if (existing == null) {
            return ResponseEntity.notFound().build();
        }
        Org org = toEntity(req, id);
        orgService.updateById(org);
        return ResponseEntity.ok(OrgDTO.fromEntity(orgService.getById(id)));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable("id") Long id) {
        boolean removed = orgService.removeById(id);
        return removed ? ResponseEntity.noContent().build() : ResponseEntity.notFound().build();
    }

    private Org toEntity(OrgRequest req, Long id) {
        Org org = new Org();
        org.setId(id);
        org.setName(req.getName());
        org.setCode(req.getCode());
        org.setType(req.getType());
        org.setTypeName(req.getTypeName());
        org.setStatus(req.getStatus());
        org.setParentId(req.getParentId());
        org.setOrderNum(req.getOrderNum() == null ? 0 : req.getOrderNum());
        return org;
    }
}
