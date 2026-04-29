package liu.alden.concbench.reactive.web;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import reactor.core.publisher.Mono;

import java.time.Duration;

/**
 * @author liuwei
 * @since 2026-04-29
 */
@RequestMapping("/benchmark")
@RestController
public class BenchmarkController {

    @GetMapping("/sleep")
    public Mono<Integer> sleep(int millis) {
        // Mono.delay is the non-blocking equivalent of Thread.sleep()
        // It allows the event loop to handle other requests while waiting
        return Mono.delay(Duration.ofMillis(millis))
                .thenReturn(millis);
    }
}