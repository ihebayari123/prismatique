# Models Folder

Place the two trained Keras model files in this folder:

- `models/date_palm_disease_model.h5`
- `models/unet_date_palm_segmentation.h5`

The API looks here first by default. You can also override the paths with:

- `DATE_PALM_CLASSIFIER_MODEL`
- `DATE_PALM_UNET_MODEL`

If you want to store the `.h5` files in GitHub, use Git LFS because one model is larger than GitHub's normal 100 MB limit.
