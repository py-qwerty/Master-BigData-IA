from mrjob.job import MRJob
from mrjob.step import MRStep

class LanguageBudgetCountries(MRJob):

    def steps(self):
        return [
            MRStep(mapper=self.mapper,
                   reducer=self.reducer)
        ]

    def mapper(self, _, line):
        # Partir la línea en campos, si hay campos faltantes ignorar la película
        fields = line.split('|')
        if len(fields) < 5:
            return

        title, language, year, country, budget = fields

        # Ignorar datos con valores desconocidos (-1)
        if language == "-1" or country == "-1" or budget == "-1":
            return

        # Emitir (idioma, país) como clave y el presupuesto como valor
        try:
            budget = int(budget)
            yield (language, country), budget
        except ValueError:
            pass  # Ignorar si el presupuesto no es un número válido

    def reducer(self, key, values):
        # Sumar presupuestos para cada (idioma, país)
        yield key, sum(values)

if __name__ == '__main__':
    LanguageBudgetCountries.run()
