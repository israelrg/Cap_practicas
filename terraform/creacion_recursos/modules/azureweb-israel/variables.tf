
variable tier_{
    
    validation {
        
        condition = var.tier_ == "Free"
        error_message = "La susbcription tiene que ser Free."
    }
}

variable size_{
    validation {
        condition = var.size_ == "F1"
        error_message = "Error prueba con F1."
    }
}