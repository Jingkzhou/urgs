let meta = #{
    name: "desktop-smoke-test",
    description: "Verify the JLIntelligentCenter Grok workflow runtime without changing workspace files",
    phases: [#{ title: "Verify", detail: "return a deterministic marker" }],
};

phase("Verify");
complete(#{ summary: "URGS-WORKFLOW-EVAL-READY" });
