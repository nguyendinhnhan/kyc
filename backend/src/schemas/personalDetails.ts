export const personalDetailsSchema = {
  type: 'object',
  required: ['dateOfBirth', 'nationality', 'phone', 'address'],
  properties: {
    dateOfBirth: {
      type: 'string',
      format: 'date',
    },
    nationality: {
      type: 'string',
      minLength: 2,
    },
    phone: {
      type: 'string',
      pattern: '^\\+?[\\d\\s-]{10,}$',
    },
    address: {
      type: 'object',
      required: ['street', 'city', 'state', 'postalCode', 'country'],
      properties: {
        street: {
          type: 'string',
          minLength: 2,
        },
        city: {
          type: 'string',
          minLength: 2,
        },
        state: {
          type: 'string',
          minLength: 2,
        },
        postalCode: {
          type: 'string',
          minLength: 3,
        },
        country: {
          type: 'string',
          minLength: 2,
        },
      },
      additionalProperties: false,
    },
  },
  additionalProperties: false,
};

export interface PersonalDetailsInput {
  dateOfBirth: string;
  nationality: string;
  phone: string;
  address: {
    street: string;
    city: string;
    state: string;
    postalCode: string;
    country: string;
  };
}
