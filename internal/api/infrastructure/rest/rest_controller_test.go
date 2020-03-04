package rest

import (
	"encoding/json"
	"errors"
	"github.com/go-chi/chi"
	"github.com/octo-technology/tezos-link/backend/internal/api/domain/model"
	"github.com/octo-technology/tezos-link/backend/internal/api/infrastructure/rest/inputs"
	"github.com/stretchr/testify/assert"
	"net/http"
	"strings"
	"testing"
)

func TestRestController_PostProject_Unit(t *testing.T) {
	// Given
	p := model.NewProject(1, "PROJECT_NAME", "AN_UUID")
	rc := buildControllerWithProjectUseCaseError(&p, nil, "CreateProject")
	rcWithError := buildControllerWithProjectUseCaseError(nil, errors.New("error from the DB"), "CreateProject")

	jsonBody, _ := json.Marshal(inputs.NewProject{
		Name: "New Project",
	})

	// Then
	t.Run("With expected JSON body", withRouter(rc.router,
		testPostProjectFunc(string(jsonBody), http.StatusCreated, `{"data":null,"status":"success"}`)))
	t.Run("With empty body", withRouter(rc.router,
		testPostProjectFunc("", http.StatusBadRequest, `{"data":"EOF","status":"fail"}`)))
	t.Run("With a use case error", withRouter(rcWithError.router,
		testPostProjectFunc(string(jsonBody), http.StatusBadRequest, `{"data":"error from the DB","status":"fail"}`)))
}

func testPostProjectFunc(jsonInput string, expectedStatus int, expectedResponse string) func(t *testing.T, router *chi.Mux) {
	return func(t *testing.T, router *chi.Mux) {
		request, err := http.NewRequest("POST", "/api/v1/projects", strings.NewReader(jsonInput))
		if err != nil {
			t.Fatal(err)
		}
		requestResponse := executeRequest(request, router)

		assert.Equal(t, expectedStatus, requestResponse.Code, "Bad status code")
		assert.Equal(t, expectedResponse, getStringWithoutNewLine(requestResponse.Body.String()), "Bad body")
	}
}

func TestRestController_GetProject_Unit(t *testing.T) {
	// Given
	p := model.NewProject(123, "A Project", "A_UUID_666")
	m := model.NewMetrics(3)

	mockProjectUsecase := &mockProjectUsecase{}
	mockProjectUsecase.
		On("FindProjectAndMetrics", "A_UUID_666").
		Return(&p, &m, nil).
		Once()
	mockHealthUsecase := &mockHealthUsecase{}
	rcc := NewRestController(chi.NewRouter(), mockProjectUsecase, mockHealthUsecase)
	rcc.Initialize()

	// When
	request, err := http.NewRequest("GET", "/api/v1/projects/A_UUID_666", nil)
	if err != nil {
		t.Fatal(err)
	}
	requestResponse := executeRequest(request, rcc.router)

	// Then
	assert.Equal(t, http.StatusOK, requestResponse.Code, "Bad status code")
	assert.Equal(t, `{"data":{"name":"A Project","uuid":"A_UUID_666","metrics":{"requestsCount":3}},"status":"success"}`, getStringWithoutNewLine(requestResponse.Body.String()), "Bad body")
}

func TestRestController_GetHealth_Unit(t *testing.T) {
	// Given
	req, err := http.NewRequest("GET", "/health", nil)
	if err != nil {
		t.Fatal(err)
	}
	health := model.NewHealth(true)
	rc := buildControllerWitHealthUseCaseReturning(&health, "Health")

	// When
	rr := executeRequest(req, rc.router)

	// Then
	expectedResponse := `{"data":{"connectedToDb":true},"status":"success"}`
	assert.Equal(t, http.StatusOK, rr.Code, "Bad status code")
	assert.Equal(t, expectedResponse, getStringWithoutNewLine(rr.Body.String()), "Bad body")
}