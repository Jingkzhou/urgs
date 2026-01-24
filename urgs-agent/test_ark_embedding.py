from volcenginesdkarkruntime import Ark

client = Ark(
    # 从环境变量中获取您的 API Key。此为默认方式，您可根据需要进行修改
    api_key="53fa1b38-6f2b-4ade-9afa-e066e2134525",
)

print("----- multimodal embeddings request -----")
resp = client.multimodal_embeddings.create(
    model="ep-20260124095335-2rwqt",
    input=[
        {"type": "text", "text": "天很蓝，海很深"},
        {
            "type": "image_url",
            "image_url": {
                "url": "https://ark-project.tos-cn-beijing.volces.com/images/view.jpeg"
            },
        },
    ],
)
print(resp)
