# docker-stuff

Jupyter notebook style Docker file tracking tensorflow master (currently 0.8) upgraded to python 3 (currently 3.4) with some data science frills I like such as pandas, matplotlib, bokeh, seaborn, statsmodels, and scikit-learn. It's easy to add more, just find that section in the dockerfile and add them in a separate line with a trailing \

See http://thomas-keller.github.io/bleeding-edge-tensor-flow-08-python3/ for more info

Separately, Parsey McParseFace was released on 05-12-16 and well, I was instantly enamored after the travesty of the renaming of Boaty McBoatyFace. Also, it's just a really cool NLP (well, natural language Understanding, to be more specific) model built on top of tensorflow, so I set about getting it to build on my weird gpu dockerfile.

Currently the uploaded dockerfile passes 6/12 tests, I don't know enough about bazel, tensorflow, or parsey mcparseface to know why its dying there yet.
