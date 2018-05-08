package main

import (
	"encoding/base64"
	"encoding/json"
	"errors"
	"io/ioutil"
	"net/http"
	"os"
	"strings"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/sjkaliski/infer"
	tf "github.com/tensorflow/tensorflow/tensorflow/go"
)

var (
	m *infer.Model
)

var (
	errInvalidImage = errors.New("invalid image supplied")
)

func handler(request events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	if len(request.Body) < 1 || !request.IsBase64Encoded {
		return events.APIGatewayProxyResponse{}, errInvalidImage
	}

	reader := base64.NewDecoder(base64.StdEncoding, strings.NewReader(request.Body))
	opts := &infer.ImageOptions{
		IsGray: false,
	}

	predictions, err := m.FromImage(reader, opts)
	if err != nil {
		return events.APIGatewayProxyResponse{}, errInvalidImage
	}

	data, err := json.Marshal(predictions[:10])
	if err != nil {
		panic(err)
	}

	return events.APIGatewayProxyResponse{
		Body:       string(data),
		StatusCode: http.StatusOK,
	}, nil
}

func init() {
	model, err := ioutil.ReadFile(os.Getenv("MODEL"))
	if err != nil {
		panic(err)
	}

	labelFile, err := ioutil.ReadFile(os.Getenv("LABELS"))
	if err != nil {
		panic(err)
	}
	labels := strings.Split(string(labelFile), "\n")

	graph := tf.NewGraph()
	err = graph.Import(model, "")
	if err != nil {
		panic(err)
	}

	m, _ = infer.New(&infer.Model{
		Graph:   graph,
		Classes: labels,
		Input: &infer.Input{
			Key:        "input",
			Dimensions: []int32{224, 224},
		},
		Output: &infer.Output{
			Key:        "output",
			Dimensions: [][]float32{},
		},
	})
}

func main() {
	lambda.Start(handler)
}
