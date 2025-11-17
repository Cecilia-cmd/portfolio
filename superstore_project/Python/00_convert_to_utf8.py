import pandas as pd

path = 'path_to_your_dataset'

df = pd.read_csv(path, encoding ='latin1')

df = df.applymap(lambda x: x.replace('\xa0', ' ') if isinstance(x, str) else x)

#save in UTF-8
clean_path = "output_path/data_superstore_utf8.csv"
df.to_csv(clean_path, index=False, encoding='utf-8')
