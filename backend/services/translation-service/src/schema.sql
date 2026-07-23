-- Cache de traducciones: cada clave de texto de la app, traducida a cada
-- idioma que algún usuario haya elegido alguna vez. Así, aunque miles de
-- socios elijan "francés", la IA solo traduce el diccionario una vez (la
-- primera persona que lo pide "paga" la latencia; el resto lee de aquí).
CREATE TABLE IF NOT EXISTS translation.translations (
  language_code TEXT NOT NULL,
  key TEXT NOT NULL,
  value TEXT NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (language_code, key)
);
