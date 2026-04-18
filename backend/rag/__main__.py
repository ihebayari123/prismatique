from .config import get_settings

# Simple smoke: prints where index is stored
if __name__ == "__main__":
    s = get_settings()
    print("data_dir:", s.data_dir)
    print("index_dir:", s.index_dir)
    print("openai_embedding_model:", s.openai_embedding_model)
