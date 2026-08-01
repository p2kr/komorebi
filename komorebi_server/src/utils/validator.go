package utils

import "github.com/go-playground/validator/v10"

var validate *validator.Validate

func InitValidator() {
	validate = validator.New(
		validator.WithRequiredStructEnabled(),
	)
}

func Validator() *validator.Validate {
	if validate == nil {
		InitValidator()
	}
	return validate
}
