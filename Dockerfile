FROM golang:bullseye AS rmapi

ENV GOPATH /go
ENV PATH ${GOPATH}/bin:/usr/local/go/bin:$PATH
ENV RMAPIREPO github.com/juruen/rmapi

RUN go get -u ${RMAPIREPO}

# see https://github.com/Kozea/WeasyPrint/issues/1384
FROM python:3.10-slim-bullseye

# rmapi
COPY --from=rmapi /go/bin/rmapi /usr/bin/rmapi

# needed to install openjdk-11-jre-headless
RUN mkdir -p /usr/share/man/man1

# imagemagick, pdftk, ghostscript, pdfcrop, weasyprint
RUN apt-get update \
    && apt-get install --no-install-recommends -y \
        libmagickwand-dev \
        pdftk \
        ghostscript \
        poppler-utils \
        build-essential \
        gcc \
        g++ \
        git

# see https://github.com/pikepdf/pikepdf
# see https://github.com/pikepdf/pikepdf/issues/194#issuecomment-1020483657
# 1. build QPDF from source
WORKDIR /tmp
RUN pip install pybind11
RUN git clone https://github.com/qpdf/qpdf.git \
    && cd qpdf \
    && ./autogen.sh \
    && ./configure \
    && make \
    && make install \
    && ldconfig /usr/local/lib

# 2. build pikepdf from source
WORKDIR /tmp
RUN git clone https://github.com/pikepdf/pikepdf && cd pikepdf && pip install .

# 3. install paper2remarkable
RUN pip install paper2remarkable

RUN useradd -u 1000 -m -U user

USER user

ENV USER user

WORKDIR /home/user

ENTRYPOINT ["p2r"]
