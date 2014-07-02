
import io.gatling.core.Predef._
import io.gatling.core.session.Expression
import io.gatling.http.Predef._
import io.gatling.jdbc.Predef._
import io.gatling.http.Headers.Names._
import io.gatling.http.Headers.Values._
import scala.concurrent.duration._
import bootstrap._
import assertions._

class ecMetal_Run extends Simulation {

	val httpProtocol = http
		.baseURL("https://api.opscode.piab:443")
		.acceptHeader("application/json")
		.acceptEncodingHeader("gzip;q=1.0,deflate;q=0.6,identity;q=0.3")
		.connection("close")
		.userAgentHeader("Chef Knife/11.14.0.alpha.4 (ruby-2.1.1-p76; ohai-7.2.0.alpha.0; x86_64-darwin13.0; +http://opscode.com)")

	val headers_1 = Map(
		"""X-Chef-Version""" -> """11.14.0.alpha.4""",
		"""X-Ops-Authorization-1""" -> """oqV3QhUuWroPYXLzhcppw3qmiH7BRLGzQ+FM6OR3U90HPgkqSER3u2dMy6Ds""",
		"""X-Ops-Authorization-2""" -> """nU/3N5/MC1r/hU4Ry2NLcfo63WCsnqUPwXzaAfMF/7YT+D73cJKTh8EAqnaC""",
		"""X-Ops-Authorization-3""" -> """iAxyPg+CFQbVsPS8NGTFhICN1kHkwzoqgX3GD9M/qZcrx8aAse8pL4vyd6QF""",
		"""X-Ops-Authorization-4""" -> """SSqaoPLCehPpB4iFgIYhfRBiRToWN+ua5LN+QTlapP8/gLb961HW5laHZPiP""",
		"""X-Ops-Authorization-5""" -> """P6lLJPsNJ+JKEX75ZZJCuPEbWOMASAzOsHOy1m7aDqPj1xDpIFfv4N+vtFBR""",
		"""X-Ops-Authorization-6""" -> """7jroXu3JagAcZCi1JX6BzT2CNMWPL2QYgv1B8fn+ow==""",
		"""X-Ops-Content-Hash""" -> """2jmj7l5rSw0yVb/vlWAYkK/YBwk=""",
		"""X-Ops-Sign""" -> """algorithm=sha1;version=1.0;""",
		"""X-Ops-Timestamp""" -> """2014-06-20T04:24:03Z""",
		"""X-Ops-Userid""" -> """tfitch""",
		"""X-Remote-Request-Id""" -> """f21eba70-ba80-42aa-b16a-bacc57e3527d""")

	val scn = scenario("ec metal verification")
		.exec(http("tfitch_clients_1")
			.get("""/organizations/tfitch/clients""")
			.headers(headers_1))
		.pause(2)
		.exec(http("tfitch_clients_2")
			.get("""/organizations/tfitch/clients""")
			.headers(headers_1))
		.pause(2)
		.exec(http("tfitch_clients_3")
			.get("""/organizations/tfitch/clients""")
			.headers(headers_1))
		)
		)

	setUp(scn.inject(atOnce(1 user))).protocols(httpProtocol)
}